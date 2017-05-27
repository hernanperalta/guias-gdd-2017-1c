CREATE VIEW stock
(stock_num, manu_code, description, unit_code, unit_price)
AS
SELECT P.stock_num, manu_code, description, unit_code, unit_price
	FROM products P JOIN product_types T
		ON(P.stock_num = T.stock_num)

-- 1) 

SELECT M.manu_code, manu_name, lead_time, monto
	FROM manufact M LEFT JOIN (SELECT manu_code, SUM(total_price) monto FROM items GROUP BY manu_code) V
		ON(V.manu_code = M.manu_code)

-- Otra solución es:

SELECT M.manu_code, manu_name, lead_time, SUM(total_price) monto
	FROM manufact M LEFT JOIN items I
		ON(I.manu_code = M.manu_code)
	GROUP BY M.manu_code, manu_name, lead_time

-- Pero el GROUP BY no tiene mucho sentido. Me parece que es más performante la primera

-- 2) 

SELECT P.stock_num, description, M.manu_code manu_code1, P2.manu_code manu_code2
	FROM manufact M JOIN products P
		ON(P.manu_code = M.manu_code)
			LEFT JOIN (SELECT P.stock_num, manu_code, description 
						FROM products P JOIN product_types T 
							ON(P.stock_num = T.stock_num)) P2
		ON(M.manu_code != P2.manu_code AND P2.stock_num = P.stock_num)
	WHERE M.manu_code > P2.manu_code OR P2.manu_code IS NULL

-- Muy rebuscado. Mejor:

SELECT P1.stock_num, T.description, P1.manu_code, P2.manu_code
	FROM products P1 JOIN product_types T
		ON(P1.stock_num = T.stock_num)
			LEFT JOIN products P2
				ON(P1.stock_num = P2.stock_num AND P1.manu_code <> P2.manu_code)
	WHERE P1.manu_code > P2.manu_code OR P2.manu_code IS NULL

-- 3) a)

SELECT C.customer_num, fname, lname
	FROM customer C
	WHERE customer_num IN (SELECT customer_num 
							FROM orders 
							GROUP BY customer_num 
							HAVING COUNT(order_num) > 1)

-- 3) b)

SELECT C.customer_num, fname, lname, cant_ordenes
INTO #clientes_temp
	FROM customer C JOIN (SELECT customer_num, COUNT(order_num) cant_ordenes FROM orders GROUP BY customer_num) O
		ON(C.customer_num = O.customer_num)
		
SELECT customer_num, fname, lname, cant_ordenes
	FROM #clientes_temp
	WHERE cant_ordenes > 1

-- 3) c)

SELECT C.customer_num, fname, lname, COUNT(order_num) cant_ordenes
	FROM customer C JOIN orders O
		ON(C.customer_num = O.customer_num)
	GROUP BY C.customer_num, fname, lname
	HAVING COUNT(order_num) > 1

-- No es lo que pide, pero bue. Es correlacionado:

SELECT C.customer_num, fname, lname, (SELECT COUNT(order_num) FROM orders O WHERE O.customer_num = C.customer_num HAVING COUNT(order_num) > 1) cant_ordenes
	FROM customer C

-- 4) No contemplé el caso de que haya una orden sin ítems (lo que haría cambiar la cantidad de órdenes)

SELECT order_num 'Número de orden', SUM(total_price) Total
	FROM items
	GROUP BY order_num
	HAVING SUM(total_price) < (SELECT SUM(total_price) / COUNT(order_num)
								FROM items)

-- 5) Correlacionado:

SELECT S.manu_code, manu_name, stock_num, description, unit_price
	FROM stock S JOIN manufact M
		ON (S.manu_code = M.manu_code)
	WHERE S.unit_price > (SELECT AVG(S.unit_price) FROM #stock S WHERE S.manu_code = manu_code)
	ORDER BY 1

-- 5) No correlacionado:

SELECT S.manu_code, manu_name, stock_num, description, unit_price
	FROM stock S JOIN manufact M
		ON(S.manu_code = M.manu_code)
			JOIN (SELECT manu_code, AVG(unit_price) prom_unit_price
					FROM stock 
					GROUP BY manu_code) P
			ON(S.manu_code = P.manu_code)
	WHERE unit_price > P.prom_unit_price

-- 6)

SELECT C.customer_num, company, order_num, order_date
	FROM customer C JOIN orders O
		ON(C.customer_num = O.customer_num)
	WHERE NOT EXISTS (SELECT item_num
						FROM items I JOIN stock S 
							ON(I.stock_num = S.stock_num AND I.manu_code = S.manu_code)
						WHERE description LIKE '%baseball gloves%' AND I.order_num = O.order_num );

-- 7)

SELECT * 
	FROM stock
	WHERE manu_code = 'HRO'
UNION
SELECT *
	FROM stock
	WHERE stock_num = 1

-- 8)

SELECT 'A' sortkey, city, company
	FROM customer
	WHERE city = 'Redwood City'
UNION
SELECT 'B' sortkey, city, company
	FROM customer
	WHERE city <> 'Redwood City'
	ORDER BY 1, city
