/*
	Notas: 
		** productos una view que hice que se ve igual al products del der 
				(es products + el campo description (que sale de joinear products con product_types))
		** si no me reconoce las tablas, poner en el código:
					USE [stores7new]
				y funca
*/

/*
1)
a)
Crear una vista que devuelva:
Código y Nombre (manu_code,manu_name) de los fabricante, posean o no productos (en tabla products),
cantidad de productos que poseen en tabla products (cant_producto) 
y la fecha de la última OC que contenga un producto suyo (ult_fecha_orden)
* De los fabricantes que fabriquen productos sólo se podrán mostrar los
que fabriquen más de un producto
* No se permite utilizar funciones definidas por usuario, ni tablas
temporales, ni UNION
*/

CREATE VIEW fabricantes_prods_ult_orden
AS
SELECT M.manu_code, M.manu_name, COUNT(stock_num) cant_producto, ult_fecha_orden
	FROM manufact M LEFT JOIN products P
		ON(M.manu_code = P.manu_code)
			LEFT JOIN (SELECT manu_code, MAX(order_date) ult_fecha_orden
					FROM orders O JOIN items I
						ON(O.order_num = I.order_num)
					GROUP BY manu_code
					) AS O
				ON(O.manu_code = M.manu_code)
	GROUP BY M.manu_code, M.manu_name, ult_fecha_orden
	HAVING COUNT(stock_num) = 0 OR COUNT(stock_num) > 1

SELECT * FROM fabricantes_prods_ult_orden

/*
Inserto dummies en manufact que no tienen registro en products para ver si funca la parte de que
posean o no productos:
INSERT INTO manufact VALUES ('PDR','Pedro',NULL,NULL,NULL,NULL)
INSERT INTO manufact VALUES ('CRL','Carlos',NULL,NULL,NULL,NULL)

Borro los dummies:
DELETE FROM manufact WHERE manu_code='PDR' OR manu_code='CRL'
*/

/*
1)
b)
Realizar una consulta sobre la vista que devuelva manu_code, manu_name,
cant_producto y si el campo ult_fecha_orden posee un NULL informar ‘No Posee
Órdenes’ si no posee NULL informar el valor de dicho campo
* No se puede utilizar UNION para el SELECT
*/	
		
SELECT manu_code, manu_name, cant_producto, COALESCE(CAST(ult_fecha_orden AS char), 'No Posee Órdenes')
	FROM fabricantes_prods_ult_orden

/*
2)
Desarrollar una consulta muestre un ABC de fabricantes que:
Liste el código de fabricante, el nombre del fabricante, la cantidad de órdenes de
compra que contentan sus productos y la suma total los productos vendidos.
Se deberán tener en cuenta sólo los fabricantes cuyo código comience con H y
posea 3 letras, y los productos cuya descripción posea el string “tennis” ó el string “ball”.
Sólo se podrán mostrar los datos de los fabricantes cuyo total sea mayor que el
total de ventas promedio por cada fabricante (Cantidad vendida / Cantidad de
fabricantes que tuvieron productos vendidos).
La consulta deberá mostrar los registros ordenados por total vendido de mayor a
menor
*/

SELECT M.manu_code, manu_name, COUNT(DISTINCT order_num) AS cant_ords, SUM(quantity) total_vendido
	FROM manufact M JOIN productos P
		ON(M.manu_code = P.manu_code)
			JOIN items I
				ON(I.manu_code = M.manu_code AND I.stock_num = P.stock_num)
	WHERE M.manu_code LIKE 'H__' AND P.description LIKE '%tennis%' OR P.description LIKE '%ball%'
	GROUP BY M.manu_code, manu_name
	HAVING SUM(quantity) > (SELECT SUM(quantity) / COUNT(DISTINCT manu_code) FROM items)
	ORDER BY 4 DESC

/*
3)
Crear una vista que devuelva:
Mostrar los datos (customer_num,lname,company) de los clientes, posean o no
órdenes de compra y la cantidad de órdenes de compra, la fecha de la última OC el
total en u$s (total_price)comprado y el total general Comprado por todos los
clientes.
De los clientes que posean órdenes sólo se podrán mostrar los clientes que tengan
alguna órden que posea productos que son fabricados por más de dos fabricantes.
Mostrar los clientes que posean menos de 5 órdenes de compra.
Ordenar el reporte primero por los clientes que tengan órdenes por cantidad de
órdenes descendente y luego por los clientes que no tengan órdenes
No se permite utilizar funciones, ni tablas temporales
*/

CREATE VIEW clientes_y_compras
AS
SELECT C.customer_num, lname, company, COUNT(O.order_num) AS cant_OCs, MAX(order_date) AS ultima_OC, SUM(total_price) AS total_comprado,
 (SELECT SUM(total_price) FROM items) AS total_general
	FROM customer C LEFT JOIN orders O
		ON(C.customer_num = O.customer_num)
			LEFT JOIN items I
				ON(O.order_num = I.order_num)
	WHERE O.order_num IS NULL OR O.order_num IN (SELECT order_num
													FROM items
													GROUP BY order_num
													HAVING COUNT(DISTINCT manu_code) > 2											
													)
	GROUP BY C.customer_num, lname, company
	HAVING COUNT(O.order_num) < 5

SELECT * FROM clientes_y_compras ORDER BY 4 DESC, 1
-- Hago este ultimo select porque el parser me dice que no puedo usar order by's en la creacion de vistas, a menos que use un top

/*
4)
Crear una vista que devuelva
El top 5 de los productos (description) que fueron más comprados en cada estado
(state) con la cantidad vendida y su precio total, teniendo en cuenta que solo se
mostrará el estado en el que tuvo mayor cantidad de ventas de un mismo producto.
Ordenarlo por la cantidad vendida descendente.
No se permite utilizar funciones, ni tablas temporales.
*/

CREATE VIEW top_5_ventas
AS
SELECT TOP 5 P1.description, C1.state, SUM(quantity) cant_vendida, SUM(total_price) precio_total_vendido
	FROM productos P1 JOIN items I1
		ON(P1.stock_num = I1.stock_num AND P1.manu_code = I1.manu_code)
			JOIN orders O1
				ON(O1.order_num = I1.order_num)
					JOIN customer C1
						ON(C1.customer_num = O1.customer_num)
	GROUP BY P1.stock_num, P1.manu_code, P1.description, C1.state
	HAVING SUM(quantity) = (SELECT MAX(cant_vendida) 
								FROM (SELECT P2.stock_num, P2.manu_code, state, SUM(quantity) cant_vendida, SUM(total_price) precio_total_vendido
										FROM productos P2 JOIN items I2
											ON(I2.stock_num = P2.stock_num AND I2.manu_code = P2.manu_code)
												JOIN orders O2
													ON(O2.order_num = I2.order_num)
														JOIN customer C2
															ON(C2.customer_num = O2.customer_num)		
										WHERE C2.state = C1.state													
										GROUP BY P2.stock_num, P2.manu_code, state) AS T5 )
	ORDER BY 3 DESC

SELECT * FROM top_5_ventas

/*
5)
a)
Se quiere averiguar los customers que no posean órdenes de compra y aquellos
cuyas últimas órdenes de compra superen el promedio de las anteriores. Se pide
mostrar customer_num, fname, lname, paid_date y el precio total, de las órdenes
que tengan la última fecha más reciente.

	Realizar la solución utilizando UNION.

Ordenar por fecha de pago descendente.
No se permite utilizar funciones, ni tablas temporales
*/

SELECT customer_num, fname, lname, 'No tiene órdenes de compra' fecha_de_pago, 'No tiene órdenes de compra' precio_total
	FROM customer
	WHERE customer_num NOT IN (SELECT customer_num FROM orders)
UNION
SELECT C.customer_num, fname, lname, CAST(O.paid_date as char) fecha_de_pago, CAST(SUM(total_price) as char) precio_total
	FROM customer C JOIN orders O
		ON(O.customer_num = C.customer_num)
			JOIN items I
				ON(I.order_num = O.order_num)
	WHERE O.order_date = (SELECT MAX(order_date) 
							FROM orders 							
							WHERE customer_num = C.customer_num							
							)
	GROUP BY C.customer_num, fname, lname, O.paid_date, O.order_date
	HAVING SUM(total_price) > (SELECT SUM(I1.total_price) / COUNT(O1.order_num) 
								FROM items I1 JOIN orders O1
									ON(I1.order_num = O1.order_num)
								WHERE O1.customer_num = C.customer_num AND O1.order_date < O.order_date			
									)
ORDER BY 4 DESC

/*
5)
b)
Se quiere averiguar los customers que no posean órdenes de compra y aquellos
cuyas últimas órdenes de compra superen el promedio de las anteriores. Se pide
mostrar customer_num, fname, lname, paid_date y el precio total, de las órdenes
que tengan la última fecha más reciente.

	Realizar la solución sin implementar UNION.

Ordenar por fecha de pago descendente.
No se permite utilizar funciones, ni tablas temporales
*/

SELECT C.customer_num, fname, lname, paid_date AS fecha_de_pago, SUM(total_price) AS precio_total
	FROM customer C LEFT JOIN orders O
		ON(C.customer_num = O.customer_num AND O.order_date = (SELECT MAX(order_date) FROM orders WHERE customer_num = C.customer_num))
			LEFT JOIN items I
				ON(I.order_num = O.order_num)
	GROUP BY C.customer_num, fname, lname, paid_date, O.order_date, O.order_num
	HAVING C.customer_num NOT IN (SELECT customer_num FROM orders) 
			OR 
		SUM(total_price) > (SELECT SUM(I1.total_price) / COUNT(O1.order_num) 
								FROM items I1 JOIN orders O1
									ON(I1.order_num = O1.order_num)
								WHERE O1.customer_num = C.customer_num AND O1.order_date < O.order_date			
									)
	ORDER BY 4 DESC

/*
6)
Se desean saber los fabricantes que vendieron mayor cantidad de un mismo
producto que la competencia con la cantidad vendida y su precio total. Tener en
cuenta que puede existir un único producto que no sea fabricado por algún otro.
No se permite utilizar funciones, ni tablas temporales
*/

SELECT manu_code, stock_num, SUM(quantity) AS cant_vendida, SUM(total_price) AS precio_total_vendido
	FROM items I1
	GROUP BY manu_code, stock_num
	HAVING SUM(quantity) > ALL (SELECT SUM(quantity)
								FROM items I2
								GROUP BY manu_code, stock_num
								HAVING I2.manu_code != I1.manu_code AND I2.stock_num = I1.stock_num
							)