/*
Hice la vista productos para no tener que andar joineando products con product_types. La vista productos es como la de products que esta en el DER
CREATE VIEW productos
(stock_num, manu_code, description, unit_code, unit_price)
AS
SELECT P.stock_num, manu_code, description, unit_code, unit_price
	FROM products P JOIN product_types T
		ON(P.stock_num = T.stock_num)

SELECT * FROM products;
SELECT * FROM productos;*/

-- 1)
SELECT C.customer_num, lname + fname AS 'Nombre y apellido', SUM(total_price) 'Total del Cliente', 
	COUNT(O.order_num) 'OCs del Cliente', (SELECT COUNT(*) FROM orders) AS 'Cant. Total OC'
		FROM customer C JOIN orders O
			ON(c.customer_num = O.customer_num)
				JOIN items I
					ON(I.order_num = O.order_num)
		WHERE C.zipcode LIKE '94%' 
GROUP BY C.customer_num, lname + fname
HAVING COUNT(O.order_num) >= 2 
			AND 
		SUM(total_price) / COUNT(O.order_num) > (SELECT SUM(total_price) / COUNT(DISTINCT order_num) from items)

-- 2) a)
SELECT P.stock_num, M.manu_code, description, manu_name, SUM(total_price) 'u$ por Producto', SUM(quantity) 'Unid. por Producto'
INTO #ABC_Productos
FROM productos P JOIN manufact M
	ON(P.manu_code = M.manu_code)
		JOIN items I
			ON(I.stock_num = P.stock_num AND I.manu_code = M.manu_code)
GROUP BY P.stock_num, M.manu_code, description, manu_name
HAVING M.manu_code IN (SELECT manu_code FROM productos GROUP BY manu_code HAVING COUNT(stock_num) >= 10 )
ORDER BY 'u$ por Producto'

SELECT * FROM #ABC_Productos
DROP TABLE #ABC_Productos

--2) b)
SELECT *
FROM #ABC_Productos
ORDER BY 5 DESC, 1, 2 

--3)
SELECT description, MONTH(order_date) 'Mes de solicitud', lname + ', ' + fname AS 'Apellido, Nombre', 
COUNT(O.order_num) 'Cant OC por mes', SUM(quantity) 'Unid Producto por mes', SUM(total_price) 'u$ Producto por mes'
	FROM #ABC_Productos ABC JOIN items I
		ON(I.stock_num = ABC.stock_num)
			JOIN orders O
				ON(O.order_num = I.order_num)
					JOIN customer C
						ON(C.customer_num = O.customer_num)
	WHERE state = (SELECT TOP 1 state 
					FROM customer 
					GROUP BY state 
					ORDER BY COUNT(customer_num) DESC)
GROUP BY description, MONTH(order_date), lname + ', ' + fname
ORDER BY 2, 1

-- 4)
SELECT C1.stock_num, C1.manu_code, C1.customer_num, C1.lname, C2.customer_num, C2.lname
	FROM
	(SELECT C.customer_num, I.stock_num, I.manu_code, lname, SUM(quantity) cantProds
		FROM orders O JOIN (SELECT * 
								FROM items 
							WHERE manu_code = 'ANZ' AND stock_num IN (5,6,9)
							) I
			ON(O.order_num = I.order_num)
				JOIN customer C
					ON(C.customer_num = O.customer_num)
		GROUP BY C.customer_num, I.stock_num, I.manu_code, lname) AS C1
			JOIN (SELECT C.customer_num, I.stock_num, I.manu_code, lname, SUM(quantity) cantProds
					FROM orders O JOIN items I
						ON(O.order_num = I.order_num)
							JOIN customer C
								ON(C.customer_num = O.customer_num)
					GROUP BY C.customer_num, I.stock_num, I.manu_code, lname) AS C2
				ON(C1.stock_num = C2.stock_num AND C1.manu_code = C2.manu_code AND C1.cantProds > C2.cantProds)

-- 5)
SELECT TOP 1 (SELECT TOP 1 COUNT(order_num) 'Mayor cant. OCs'
			FROM orders
			GROUP BY customer_num
			ORDER BY 1 DESC), 
		(SELECT TOP 1 COUNT(order_num) 'Menor cant. OCs'
			FROM orders
			GROUP BY customer_num
			ORDER BY 1 ASC), 
		(SELECT TOP 1 SUM(total_price) 'Mayor total u$ ordenado'
			FROM items I JOIN orders O
				ON(O.order_num = I.order_num)
			GROUP BY customer_num
			ORDER BY 1 DESC), 
		(SELECT TOP 1 SUM(total_price) 'Menor total u$ ordenado'
			FROM items I JOIN orders O
			ON(O.order_num = I.order_num)
			GROUP BY customer_num
			ORDER BY 1 ASC), 
		(SELECT TOP 1 COUNT(item_num) 'Mayor cant. items solicitados'
			FROM orders O JOIN items I
			ON(I.order_num = O.order_num)
			GROUP BY customer_num
			ORDER BY 1 DESC), COUNT(item_num) 'Menor cant. items solicitados'
				FROM orders O JOIN items I
					ON(I.order_num = O.order_num)
				GROUP BY customer_num
				ORDER BY 6 ASC

-- 6)
SELECT SUM(total_price) total_cobrado, C.customer_num
	FROM orders O JOIN customer C
		ON(O.customer_num = C.customer_num)
			JOIN items I
				ON(I.order_num = O.order_num)
	WHERE state = 'CA' AND YEAR(O.paid_date) = 1998
	GROUP BY C.customer_num
	HAVING COUNT(O.order_num) > 4 AND COUNT(item_num) > (SELECT TOP 1 COUNT(item_num)
															FROM orders O JOIN items I
																ON(O.order_num = I.order_num)
																	JOIN customer C
																		ON(O.customer_num = C.customer_num)
															WHERE state = 'AK' AND YEAR(O.paid_date) = 1998
															GROUP BY O.order_num
															ORDER BY 1 DESC
																)

-- 7)
SELECT P.manu_code, M.manu_name, P.stock_num, description, SUM(quantity) AS ComprasDeOtrosFabricantes
	FROM productos P JOIN manufact M
		ON(M.manu_code = P.manu_code)
			JOIN items I
				ON(P.stock_num = I.stock_num AND P.manu_code != I.manu_code)			 
	WHERE description LIKE '%shoes%' AND P.stock_num IN (SELECT stock_num
															FROM productos
															GROUP BY stock_num
															HAVING COUNT(manu_code) > 2)
	GROUP BY P.manu_code, M.manu_name, P.stock_num, description
	HAVING SUM(quantity) < 10

-- 8)					
SELECT S.code 'Código Estado', S.sname 'Descripción Estado', C1.lname + ', ' + C1.fname 'Apellido, Nombre', C2.lname + ', ' + C2.fname 'Apellido, Nombre',
 monto_total1 + monto_total2 'Total Solicitado'
	FROM customer C1 JOIN (SELECT TOP 2 C.customer_num, SUM(total_price) monto_total1
							FROM orders O JOIN items I
								ON(O.order_num = I.order_num)
									JOIN customer C
										ON(C.customer_num = O.customer_num)
							WHERE state = 'CA'
							GROUP BY C.customer_num
							ORDER BY 2 DESC) AS O1
		ON(C1.customer_num = O1.customer_num)
			JOIN (SELECT TOP 2 C.customer_num, C.lname, C.fname, SUM(total_price) monto_total2
					FROM orders O JOIN items I
						ON(O.order_num = I.order_num)
							JOIN customer C
								ON(C.customer_num = O.customer_num)
					WHERE state = 'CA'
					GROUP BY C.customer_num, C.lname, C.fname
					ORDER BY 4 DESC) AS C2
				ON(C2.customer_num < O1.customer_num)
					JOIN state S
						ON(S.code = C1.state)

-- 9)
SELECT C2.order_num, C2.customer_num, C2.order_date, DATEADD(day,1,C2.order_date + tiempo_manufact) AS fecha_modificada
	FROM (SELECT TOP 1 O.order_num, O.customer_num, SUM(quantity) cantProds, M.lead_time AS tiempo_manufact
			FROM orders O JOIN items I
				ON(O.order_num = I.order_num)
					JOIN manufact M
						ON(M.manu_code = I.manu_code)
			WHERE I.manu_code = 'ANZ'
			GROUP BY O.order_num, O.customer_num, M.lead_time
			ORDER BY 3 DESC
				) C1 RIGHT JOIN (SELECT TOP 5 O.order_num, O.customer_num, SUM(quantity) AS cant_prods, O.order_date
									FROM orders O JOIN items I
										ON(O.order_num = I.order_num)
									WHERE I.manu_code = 'ANZ'
									GROUP BY O.order_num, O.order_date, O.customer_num
									ORDER BY 3 DESC
								) C2
		ON(C1.customer_num != C2.customer_num)
	ORDER BY 4